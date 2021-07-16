//SourceUnit: TKS.sol

pragma solidity ^0.4.25;

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

contract Ownable {

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = address(0x4172bee2cf43f658f3edf5f4e08bab03b5f777fa0a);
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

contract TKS is Ownable {

    uint256 ACTIVATION_TIME = 1578769200;

    modifier isActivated {
        require(now >= ACTIVATION_TIME);
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

    event onDistribute(
        address indexed customerAddress,
        uint256 price
    );

    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingTron,
        uint256 tokensMinted,
        uint timestamp
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 tronEarned,
        uint timestamp
    );

    event onReinvestment(
        address indexed customerAddress,
        uint256 tronReinvested,
        uint256 tokensMinted
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 tronWithdrawn
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    string public name = "Tewkenaire Stable";
    string public symbol = "TKS";
    uint8 constant public decimals = 6;

    uint256 internal entryFee_ = 10;
    uint256 internal transferFee_ = 1;
    uint256 internal exitFee_ = 10;
    uint256 internal tewkenaireFee_ = 10; // 10% of the 10% buy or sell fees makes it 1%
    uint256 internal maintenanceFee_ = 10; // 10% of the 10% buy or sell fees makes it 1%
    address internal maintenanceAddress;

    address public distributionAddress;
    uint256 public totalTronFundCollected;

    uint256 constant internal magnitude = 2 ** 64;
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public withdrawals;
    uint256 internal tokenSupply_;
    uint256 internal profitPerShare_;
    uint256 public totalHolder = 0;
    uint256 public totalDonation = 0;

    constructor() public {
        maintenanceAddress = address(0x4172bee2cf43f658f3edf5f4e08bab03b5f777fa0a);
        distributionAddress = address(0x41db2f538c702f95a441e5e4dd3742b95856fdd118);
    }

    function distribute() public payable returns (uint256) {
        require(msg.value > 0, "must be a positive value");
        totalDonation += msg.value;
        profitPerShare_ = SafeMath.add(profitPerShare_, (msg.value * magnitude) / tokenSupply_);
        emit onDistribute(msg.sender, msg.value);
    }

    function buy() public payable returns (uint256) {
        return purchaseTokens(msg.sender, msg.value);
    }

    function buyFor(address _customerAddress) public payable returns (uint256) {
        return purchaseTokens(_customerAddress, msg.value);
    }

    function() payable public {
        purchaseTokens(msg.sender, msg.value);
    }

    function reinvest() onlyDivis public {
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends();
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        uint256 _tokens = purchaseTokens(_customerAddress, _dividends);
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }

    function exit() external {
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if (_tokens > 0) sell(_tokens);
        withdraw();
    }

    function withdraw() onlyDivis public {
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends();
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);
        _customerAddress.transfer(_dividends);
        withdrawals[_customerAddress] += _dividends;
        emit onWithdraw(_customerAddress, _dividends);
    }

    function sell(uint256 _amountOfTokens) onlyTokenHolders public {
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_amountOfTokens, exitFee_), 100);

        uint256 _maintenance = SafeMath.div(SafeMath.mul(_undividedDividends, maintenanceFee_),100);
        maintenanceAddress.transfer(_maintenance);

        uint256 _tewkenaire = SafeMath.div(SafeMath.mul(_undividedDividends, tewkenaireFee_), 100);
        totalTronFundCollected += _tewkenaire;
        distributionAddress.transfer(_tewkenaire);

        uint256 _dividends = SafeMath.sub(_undividedDividends, SafeMath.add(_maintenance,_tewkenaire));
        uint256 _taxedTron = SafeMath.sub(_amountOfTokens, _undividedDividends);

        tokenSupply_ = SafeMath.sub(tokenSupply_, _amountOfTokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

        int256 _updatedPayouts = (int256) (profitPerShare_ * _amountOfTokens + (_taxedTron * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

        if (tokenSupply_ > 0) {
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }

        emit Transfer(_customerAddress, address(0), _amountOfTokens);
        emit onTokenSell(_customerAddress, _amountOfTokens, _taxedTron, now);
    }

    function transfer(address _toAddress, uint256 _amountOfTokens) onlyTokenHolders external returns (bool){
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

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

    function totalTronBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function totalSupply() public view returns (uint256) {
        return tokenSupply_;
    }

    function myTokens() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    function myDividends() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return dividendsOf(_customerAddress);
    }

    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }

    function dividendsOf(address _customerAddress) public view returns (uint256) {
        return (uint256) ((int256) (profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

    function sellPrice() public view returns (uint256) {
        uint256 _tron = 1e6;
        uint256 _dividends = SafeMath.div(SafeMath.mul(_tron, exitFee_), 100);
        uint256 _taxedTron = SafeMath.sub(_tron, _dividends);

        return _taxedTron;
    }

    function buyPrice() public view returns (uint256) {
        uint256 _tron = 1e6;
        uint256 _dividends = SafeMath.div(SafeMath.mul(_tron, entryFee_), 100);
        uint256 _taxedTron = SafeMath.add(_tron, _dividends);

        return _taxedTron;
    }

    function calculateTokensReceived(uint256 _tronToSpend) public view returns (uint256) {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_tronToSpend, entryFee_), 100);
        uint256 _amountOfTokens = SafeMath.sub(_tronToSpend, _dividends);

        return _amountOfTokens;
    }

    function calculateTronReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_tokensToSell, exitFee_), 100);
        uint256 _taxedTron = SafeMath.sub(_tokensToSell, _dividends);

        return _taxedTron;
    }

    function purchaseTokens(address _customerAddress, uint256 _incomingTron) internal isActivated returns (uint256) {
        if (deposits[_customerAddress] == 0) {
          totalHolder++;
        }

        deposits[_customerAddress] += _incomingTron;

        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingTron, entryFee_), 100);

        uint256 _maintenance = SafeMath.div(SafeMath.mul(_undividedDividends, maintenanceFee_), 100);
        maintenanceAddress.transfer(_maintenance);

        uint256 _tewkenaire = SafeMath.div(SafeMath.mul(_undividedDividends, tewkenaireFee_), 100);
        totalTronFundCollected += _tewkenaire;
        distributionAddress.transfer(_tewkenaire);

        uint256 _dividends = SafeMath.sub(_undividedDividends, SafeMath.add(_tewkenaire,_maintenance));
        uint256 _amountOfTokens = SafeMath.sub(_incomingTron, _undividedDividends);
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
        emit onTokenPurchase(_customerAddress, _incomingTron, _amountOfTokens, now);

        return _amountOfTokens;
    }
}