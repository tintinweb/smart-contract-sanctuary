pragma solidity ^0.4.13;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract MultiOwnable {
    address[] public owners;

    function ownersCount() public view returns(uint256) {
        return owners.length;
    }

    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);

    constructor() public {
        owners.push(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }

    function isOwner(address addr) public view returns (bool) {
        bool _isOwner = false;
        for (uint i=0; i<owners.length; i++) {
            if (addr == owners[i]) {
                _isOwner = true;
                break;
            }
        }
        return _isOwner;
    }

    function addOwner(address owner) public onlyOwner {
        require(owner != address(0));
        require(!isOwner(owner));
        owners.push(owner);
        emit OwnerAdded(owner);
    }
    function removeOwner(address owner) public onlyOwner {
        require(owner != address(0));
        require(owner != msg.sender);
        bool wasDeleted = false;
        for (uint i=0; i<owners.length; i++) {
            if (owners[i] == owner) {
                if (i < owners.length-1) {
                    owners[i] = owners[owners.length-1];
                }
                owners.length--;
                wasDeleted = true;
            }
        }
        require(wasDeleted);
        emit OwnerRemoved(owner);
    }

}

contract AigoTokensale is MultiOwnable {

  struct InvestorPayment {
    uint256 time;
    uint256 value;
    uint8 currency;
    uint256 tokens;
  }

  struct Investor {
    bool isActive;
    InvestorPayment[] payments;
    bool needUpdate;
  }

  event InvestorAdded(address indexed investor);
  event TokensaleFinishTimeChanged(uint256 oldTime, uint256 newTime);
  event Payment(address indexed investor, uint256 value, uint8 currency);
  event Delivered(address indexed investor, uint256 amount);
  event TokensaleFinished(uint256 tokensSold, uint256 tokensReturned);

  ERC20Basic public token;
  uint256 public finishTime;
  address vaultWallet;

  UserWallet[] public investorList;
  mapping(address => Investor) investors;

  function investorsCount() public view returns (uint256) {
    return investorList.length;
  }
  function investorInfo(address investorAddress) public view returns (bool, bool, uint256, uint256) {
    Investor storage investor = investors[investorAddress];
    uint256 investorTokens = 0;
    for (uint i=0; i<investor.payments.length; i++) {
      investorTokens += investor.payments[i].tokens;
    }
    return (investor.isActive, investor.needUpdate, investor.payments.length, investorTokens);
  }
  function investorPayment(address investor, uint index) public view returns (uint256,  uint256, uint8, uint256) {
    InvestorPayment storage payment = investors[investor].payments[index];
    return (payment.time, payment.value, payment.currency, payment.tokens);
  }
  function totalTokens() public view returns (uint256) {
    return token.balanceOf(this);
  }

  constructor(ERC20Basic _token, uint256 _finishTime, address _vaultWallet) MultiOwnable() public {
    require(_token != address(0));
    require(_finishTime > now);
    require(_vaultWallet != address(0));
    token = _token;
    finishTime = _finishTime;
    vaultWallet = _vaultWallet;
  }

  function setFinishTime(uint256 _finishTime) public onlyOwner {
    uint256 oldTime = finishTime;
    finishTime = _finishTime;
    emit TokensaleFinishTimeChanged(oldTime, finishTime);
  }

  function postWalletPayment(uint256 value) public {
    require(now < finishTime);
    Investor storage investor = investors[msg.sender];
    require(investor.isActive);
    investor.payments.push(InvestorPayment(now, value, 0, 0));
    investor.needUpdate = true;
    emit Payment(msg.sender, value, 0);
  }

  function postExternalPayment(address investorAddress, uint256 time, uint256 value, uint8 currency, uint256 tokenAmount) public onlyOwner {
    require(investorAddress != address(0));
    require(time <= now);
    require(now < finishTime);
    Investor storage investor = investors[investorAddress];
    require(investor.isActive);
    investor.payments.push(InvestorPayment(time, value, currency, tokenAmount));
    emit Payment(msg.sender, value, currency);
  }

  function updateTokenAmount(address investorAddress, uint256 paymentIndex, uint256 tokenAmount) public onlyOwner {
    Investor storage investor = investors[investorAddress];
    require(investor.isActive);
    investor.needUpdate = false;
    investor.payments[paymentIndex].tokens = tokenAmount;
  }

  function addInvestor(address _payoutAddress) public onlyOwner {
    UserWallet wallet = new UserWallet(_payoutAddress, vaultWallet);
    investorList.push(wallet);
    investors[wallet].isActive = true;
    emit InvestorAdded(wallet);
  }

  function deliverTokens(uint limit) public onlyOwner {
    require(now > finishTime);
    uint counter = 0;
    uint256 tokensDelivered = 0;
    for (uint i = 0; i < investorList.length && counter < limit; i++) {
      UserWallet investorAddress = investorList[i];
      Investor storage investor = investors[investorAddress];
      require(!investor.needUpdate);
      uint256 investorTokens = 0;
      for (uint j=0; j<investor.payments.length; j++) {
        investorTokens += investor.payments[j].tokens;
      }
      if (investor.isActive) {
        counter = counter + 1;
        require(token.transfer(investorAddress, investorTokens));
        investorAddress.onDelivery();
        investor.isActive = false;
        emit Delivered(investorAddress, investorTokens);
      }
      tokensDelivered = tokensDelivered + investorTokens;
    }
    if (counter < limit) {
      uint256 tokensLeft = token.balanceOf(this);
      if (tokensLeft > 0) {
        require(token.transfer(vaultWallet, tokensLeft));
      }
      emit TokensaleFinished(tokensDelivered, tokensLeft);
    }
  }

}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract UserWallet {
    using SafeMath for uint256;

    address public payoutWallet;
    address public vaultWallet;
    AigoTokensale public tokensale;

    constructor(address _payoutWallet, address _vaultWallet) public {
      require(_vaultWallet != address(0));
      payoutWallet = _payoutWallet;
      vaultWallet = _vaultWallet;
      tokensale = AigoTokensale(msg.sender);
    }

    function onDelivery() public {
        require(msg.sender == address(tokensale));
        if (payoutWallet != address(0)) {
            ERC20Basic token = tokensale.token();
            uint256 balance = token.balanceOf(this);
            require(token.transfer(payoutWallet, balance));
        }
    }

    function setPayoutWallet(address _payoutWallet) public {
        require(tokensale.isOwner(msg.sender));
        payoutWallet = _payoutWallet;
        if (payoutWallet != address(0)) {
            ERC20Basic token = tokensale.token();
            uint256 balance = token.balanceOf(this);
            if (balance > 0) {
                require(token.transfer(payoutWallet, balance));
            }
        }
    }

    function() public payable {
        tokensale.postWalletPayment(msg.value);
        vaultWallet.transfer(msg.value);
    }

}