pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract BCEOTokenInterface {
  function owner() public view returns (address);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool success);
}

contract BitCEOIcoBase is Ownable {

  using SafeMath for uint256;

  struct WithdrawInterval {
    uint256 prevTimestamp;
    uint256 nextTimestamp;
    uint256 balance;
    bool    isFinished; 
  }

  bool  public          isICOEnabled  = false;
  uint8 public constant decimals  = 18;

  uint8 internal constant TEAM    = 1; 
  uint8 internal constant REVERSE = 2;
  uint8 internal constant BCEO    = 1;
  uint8 internal constant ETH70   = 2; 
  uint8 internal constant ETH100  = 3;
  
  uint256 public MIN_AMOUNT_INVEST             = 1 * uint256(10 ** 17);                 // 0.1 Ether
  uint256 public RATE_ICO_70                   = 18000;                                 // Rate ETH/BCEO when deposit 70%
  uint256 public RATE_ICO_100                  = 15000;                                 // Rate ETH/BCEO when deposit 100%
  uint256 public TEAM_WITHDRAW_PER_MONTH       = 14583000 * (10 ** uint256(decimals));  // 14.583.000 BCEO
  uint256 public REVERSE_WITHDRAW_PER_MONTH    = 14583000 * (10 ** uint256(decimals));  // 14.583.000 BCEO
  uint256[3] public PRE_SALES = [
    70000000 * (10 ** uint256(decimals)),   // 70.000.000 BCEO, presale 1
    126000000 * (10 ** uint256(decimals)),  // 126.000.000 BCEO, presale 2
    170100000 * (10 ** uint256(decimals))   // 170.100.000 BCEO, presale 3
  ];
  
  uint256 public BountyBalance           = 122500000 * (10 ** uint256(decimals)); // 122.500.000 BCEO
  uint256 public TeamBalance             = 875000000 * (10 ** uint256(decimals)); // 875.000.000 BCEO
  uint256 public ReserveBalance          = 678900000 * (10 ** uint256(decimals)); // 678.900.000 BCEO
  uint256 public CommunityBalance        = 175000000 * (10 ** uint256(decimals)); // 175.000.000 BCEO
  uint256 public PrivateSaleBalance      = 262500000 * (10 ** uint256(decimals)); // 262.500.000 BCEO
  uint256 public PreSaleBalance          = 366100000 * (10 ** uint256(decimals)); // 366.100.000 BCEO
  uint256 public IcoPublicBalance        = 510000000 * (10 ** uint256(decimals)); // 510.000.000 BCEO
  uint256 public Ico70PercentBalance     = 360000000 * (10 ** uint256(decimals)); // 360.000.000 BCEO
  uint256 public Ico100PercentBalance    = 150000000 * (10 ** uint256(decimals)); // 150.000.000 BCEO

  uint256 public amountEtherLock = 0;
  uint256 public amountEtherNotLock = 0;

  mapping (string => uint256) TIMES_CONSTANT;

  address public owner;
  address public ownerBCEO;
  address public addressBCEO; 

  BCEOTokenInterface tokenBCEO;
  WithdrawInterval teamWithdraw;
  WithdrawInterval reserveWithdraw;
  WithdrawInterval presaleWithdraw;

  mapping (uint8 => mapping (address => uint256)) public balanceOf; 

  event Deposit(string sType, address user, uint256 amount, uint256 balance);
  event Convert(string sType, address user, uint256 amount, uint256 balance);
  event Withdraw(string sType, address user, uint256 amount);

  constructor(uint256[8] _times) public {
    require(_times.length == 8, "Not enough values");
    string[8] memory constant_names = [
      "WITHDRAW_BEGIN",
      "WITHDRAW_ETH_END",
      "TEAM_WITHDRAW_BEGIN",
      "REVERSE_WITHDRAW_BEGIN",
      "PRESALE_WITHDRAW_BEGIN",
      "ICO_BEGIN",
      "TEAM_WITHDRAW_INTERVAL",
      "PRESALE_WITHDRAW_INTERVAL"
    ];

    for (uint i = 0; i < _times.length; i++) {
      require(TIMES_CONSTANT[constant_names[i]] == 0x0, "Can not redefine constant");
      TIMES_CONSTANT[constant_names[i]] = _times[i];
    }

    teamWithdraw    = WithdrawInterval(0, TIMES_CONSTANT["TEAM_WITHDRAW_BEGIN"], TeamBalance, false);
    reserveWithdraw = WithdrawInterval(0, TIMES_CONSTANT["REVERSE_WITHDRAW_BEGIN"], ReserveBalance, false);
    presaleWithdraw = WithdrawInterval(0, TIMES_CONSTANT["PRESALE_WITHDRAW_BEGIN"], PreSaleBalance, false);
  }

  // Fallback function, revert when some one send Ether directly to the contract
  function () public payable {
    revert();
  }

  function startICO(address _addressBCEO) public onlyOwner returns (bool) {
    require(!isICOEnabled);
    require(_addressBCEO != 0x0);
    addressBCEO = _addressBCEO;
    tokenBCEO = BCEOTokenInterface(addressBCEO);
    ownerBCEO = tokenBCEO.owner();
    
    // Calculate the total amount BCEO
    uint256 totalCap =  BountyBalance + TeamBalance + ReserveBalance
      + CommunityBalance + PrivateSaleBalance + PreSaleBalance
      + IcoPublicBalance + Ico70PercentBalance + Ico100PercentBalance; // 3.500.000.000

    // ICO Contract must hold enough BCEO to start ICO campaign 
    require(tokenBCEO.balanceOf(this) ==  totalCap);

    // Transfer BCEO of Bounty, Commynity, PrivateSale, IcoPublic to owner immediately
    require(tokenBCEO.transfer(ownerBCEO, BountyBalance));
    require(tokenBCEO.transfer(ownerBCEO, CommunityBalance));
    require(tokenBCEO.transfer(ownerBCEO, PrivateSaleBalance));
    require(tokenBCEO.transfer(ownerBCEO, IcoPublicBalance));

    // Start ICO campaign
    isICOEnabled = true;
    return true;
  }

  function deposit70Percent() public payable isICOStarted {
    // Number of tokens to sale in wei.
    uint256 amount = msg.value.mul(RATE_ICO_70);

    // Remain balance.
    require(Ico70PercentBalance >= amount);

    // Minimum amount invest is 0.1 Ether.
    if (msg.value < MIN_AMOUNT_INVEST) {
      revert();
    }
    
    // Calculate the amount Ether: 30% to lock and 70% not.
    uint256 oneTenth = msg.value.div(10);
    uint256 threeTenth = oneTenth.mul(3);
    uint256 seventTenth = msg.value.sub(threeTenth);
    
    // Store balance of investor: ETH70 and BCEO
    balanceOf[ETH70][msg.sender] = balanceOf[ETH70][msg.sender].add(seventTenth);
    balanceOf[BCEO][msg.sender] = balanceOf[BCEO][msg.sender].add(amount);
    emit Deposit("DEPOSIT_ICO_70", msg.sender, msg.value,  balanceOf[ETH70][msg.sender]);

    // Lock Ether deposited by investor
    amountEtherLock = amountEtherLock.add(seventTenth);
    amountEtherNotLock = amountEtherNotLock.add(threeTenth);
    Ico70PercentBalance = Ico70PercentBalance.sub(amount);
  }

  function deposit100Percent() public payable isICOStarted {

    // Number of tokens to sale in wei.
    uint256 amount = msg.value.mul(RATE_ICO_100);

    // Remain balance.
    require(Ico100PercentBalance >= amount);
    
    // Minimum amount invest is 0.1 Ether.
    if (msg.value < MIN_AMOUNT_INVEST) {
      revert();
    }

    // Store balance of investor: ETH100 and BCEO.
    balanceOf[BCEO][msg.sender] = balanceOf[BCEO][msg.sender].add(amount);
    balanceOf[ETH100][msg.sender] = balanceOf[ETH100][msg.sender].add(msg.value);
    emit Deposit("DEPOSIT_ICO_100", msg.sender, msg.value,  balanceOf[ETH100][msg.sender]);

    // Lock Ether deposited by investor.
    amountEtherLock = amountEtherLock.add(msg.value);
    Ico100PercentBalance = Ico100PercentBalance.sub(amount);
  }

  function convertDeposit100to70(address _investorAddress) public onlyOwner returns (bool) {
    uint256 amountETH100 =  balanceOf[ETH100][_investorAddress];
    require(amountETH100 >= MIN_AMOUNT_INVEST);

    // Number of tokens in wei will be converted
    uint256 amount = amountETH100.mul(RATE_ICO_70 - RATE_ICO_100);

    // Remain balance.
    require(Ico70PercentBalance >= amount);

    // Calculate the amount Ether: 30% to lock and 70% not.
    uint256 oneTenth = amountETH100.div(10);
    uint256 threeTenth = oneTenth.mul(3);
    uint256 seventTenth = amountETH100.sub(threeTenth);
    
    // Store balance of investor: ETH70 and BCEO
    balanceOf[BCEO][_investorAddress] = balanceOf[BCEO][_investorAddress].add(amount);
    balanceOf[ETH70][_investorAddress] = balanceOf[ETH70][_investorAddress].add(seventTenth);
    balanceOf[ETH100][_investorAddress] = 0;
    emit Convert("100_TO_70", _investorAddress, amountETH100,  balanceOf[ETH70][_investorAddress]);

    // Unlock 30% amount Ether
    amountEtherLock = amountEtherLock.sub(threeTenth);
    amountEtherNotLock = amountEtherNotLock.add(threeTenth);

    // Transfer amount BCEO sold from Ico100 to Ico70
    Ico70PercentBalance = Ico70PercentBalance.sub(amountETH100.mul(RATE_ICO_70));
    Ico100PercentBalance = Ico100PercentBalance.add(amountETH100.mul(RATE_ICO_100));
  }

  function withdrawEther() public isICOStarted returns (bool) {
    // Balances of investor.
    uint256 amountBCEO =  balanceOf[BCEO][msg.sender];
    uint256 amountETH70 =  balanceOf[ETH70][msg.sender];
    uint256 amountETH100 =  balanceOf[ETH100][msg.sender];
    uint256 amountEther = amountETH70.add(amountETH100);

    // Validates balance and timestamp.
    require(block.timestamp >= TIMES_CONSTANT["WITHDRAW_BEGIN"] && block.timestamp <= TIMES_CONSTANT["WITHDRAW_ETH_END"]);
    require(amountEther > 0);

    // Investor withdraws Ether so reduces the amount Ether and back BCEO to ICOBalance.
    uint256 amountBCEO100 = amountETH100.mul(RATE_ICO_100);
    uint256 amountBCEO70 = amountBCEO.sub(amountBCEO100);
    amountEtherLock = amountEtherLock.sub(amountEther);
    if (amountBCEO100 > 0) {
      Ico100PercentBalance = Ico100PercentBalance.add(amountBCEO100);
    }
    if (amountBCEO70 > 0) {
      Ico100PercentBalance = Ico100PercentBalance.add(amountBCEO70);
    }

    // Set balances&#39; Investor to 0 after withdrawing.
    balanceOf[BCEO][msg.sender] = 0;
    balanceOf[ETH70][msg.sender] = 0;
    balanceOf[ETH100][msg.sender] = 0;
    
    // Transfer
    if (!msg.sender.send(amountEther)) revert();

    emit Withdraw("ETH", msg.sender, amountEther);
    return true;
  }

  function withdrawBCEO() public isICOStarted returns (bool) {
    // Balances of invester.
    uint256 amountBCEO =  balanceOf[BCEO][msg.sender];
    uint256 amountETH70 =  balanceOf[ETH70][msg.sender];
    uint256 amountETH100 =  balanceOf[ETH100][msg.sender];
    uint256 amountEther = amountETH70.add(amountETH100); 

    // Validates balance and timestamp.
    require(block.timestamp >= TIMES_CONSTANT["WITHDRAW_BEGIN"]);
    require(amountBCEO > 0);

    // Investor withdraws BCEO so unlock his Ether.
    amountEtherLock = amountEtherLock.sub(amountEther);
    amountEtherNotLock = amountEtherNotLock.add(amountEther);

    // Set balances&#39; Investor to 0 after withdrawing.
    balanceOf[ETH70][msg.sender] = 0;
    balanceOf[ETH100][msg.sender] = 0;
    balanceOf[BCEO][msg.sender] = 0;

    if (!tokenBCEO.transfer(msg.sender, amountBCEO)) {
      revert();
    }

    emit Withdraw("BCEO", msg.sender, amountBCEO);
    return true;
  }

  function adminWithdrawEther() public onlyOwner isICOStarted returns (bool) {
    // Unlock all Ether after TIMES_CONSTANT["WITHDRAW_ETH_END"] 
    if (block.timestamp > TIMES_CONSTANT["WITHDRAW_ETH_END"]) {
      amountEtherNotLock = amountEtherNotLock.add(amountEtherLock);
      amountEtherLock = 0;
    }

    require(amountEtherNotLock > 0);

    // After withdrawing, reset avaialbe amountEtherNotLock to 0    
    if (!ownerBCEO.send(amountEtherNotLock)) {
      revert();
    }
    amountEtherNotLock = 0;
    return true;
  }

  function adminWithdrawBCEO(uint8 _withdrawType) public onlyOwner isICOStarted returns (bool) {
    WithdrawInterval memory theWithdraw;
    // Only accept _withdrawType is either TEAM (1) or REVERSE (2).
    if (_withdrawType == TEAM) {
      theWithdraw = teamWithdraw;
    } 
    else if (_withdrawType == REVERSE) {
      theWithdraw = reserveWithdraw;
    } 
    else {
      revert();
    }
    require(!theWithdraw.isFinished);
    
    // Calculate the avaiable amount can be withdrawn
    uint256 currentAvailableBalance = 0;
    while (block.timestamp >= theWithdraw.nextTimestamp && theWithdraw.balance > 0) {
      // Amount BCEO can be withdrawn in each interval
      uint256 withdrawAmount = min(REVERSE_WITHDRAW_PER_MONTH, theWithdraw.balance);

      currentAvailableBalance            = currentAvailableBalance.add(withdrawAmount);
      theWithdraw.balance                = theWithdraw.balance.sub(withdrawAmount);
      theWithdraw.prevTimestamp          = theWithdraw.nextTimestamp;
      theWithdraw.nextTimestamp          = theWithdraw.nextTimestamp + TIMES_CONSTANT["TEAM_WITHDRAW_INTERVAL"];
    }
    
    // After withdrawing, reset available amount to 0
    if (!tokenBCEO.transfer(ownerBCEO, currentAvailableBalance)) {
      revert();
    }
    
    // If balance = 0, finish withdrawal
    if (theWithdraw.balance == 0) {
      theWithdraw.isFinished = true;
    }
    return true;
  }

  function adminWithdrawBCEOPreSale() public onlyOwner isICOStarted returns (bool) {
    require(!presaleWithdraw.isFinished);
    
    uint256 totalWithdrawAmount = 0;
    // Calculate the avaiable amount can be withdrawn
    while (block.timestamp >= presaleWithdraw.nextTimestamp && presaleWithdraw.balance > 0) {
      uint256 withdrawAmount = 0;
      for (uint8 i = 0; i < PRE_SALES.length; i++) {
      
        if (PRE_SALES[i] > 0) {
          withdrawAmount = min(PRE_SALES[i], presaleWithdraw.balance);
          PRE_SALES[i] = 0;
          break;
        }
      }

      totalWithdrawAmount           = totalWithdrawAmount.add(withdrawAmount);
      presaleWithdraw.balance       = presaleWithdraw.balance.sub(withdrawAmount);
      presaleWithdraw.prevTimestamp = presaleWithdraw.nextTimestamp;
      presaleWithdraw.nextTimestamp = presaleWithdraw.nextTimestamp + TIMES_CONSTANT["PRESALE_WITHDRAW_INTERVAL"];
    }

    // After withdrawing, reset avaialbe amount to 0
    if (!tokenBCEO.transfer(ownerBCEO, totalWithdrawAmount)) {
      revert();
    }

    // If balance = 0, finish withdrawal
    if (presaleWithdraw.balance == 0) {
      presaleWithdraw.isFinished = true;
    }
    return true;
  }

  function min(uint256 a, uint256 b) public pure returns (uint256) {
    return a < b ? a : b;
  }
  
  modifier isICOStarted() {
    require(isICOEnabled);
    require(block.timestamp >= TIMES_CONSTANT["ICO_BEGIN"]);
    _;
  }
}

contract BitCEOIco is BitCEOIcoBase {

  constructor() BitCEOIcoBase (
    [
      uint256(1540626524), //  May 1 st, 2019 00:00:00 GMT+07:00 WITHDRAW_BEGIN
      uint256(1556902799), //  May 3 rd, 2019 23:59:59 GMT+07:00 WITHDRAW_ETH_END
      uint256(1485709200), //  Dec 1 st, 2019 00:00:00 GMT+07:00 TEAM_WITHDRAW_BEGIN
      uint256(1477554524), //  Dec 1 st, 2018 00:00:00 GMT+07:00 REVERSE_WITHDRAW_BEGIN
      uint256(1540626524), //  Nov 22nd, 2018 01:11:11 GMT+07:00 PRESALE_WITHDRAW_BEGIN
      uint256(1540626524), //  Dec 1 st, 2018 00:00:00 GMT+07:00 ICO_BEGIN
      uint256(30 days),    //                                    TEAM_WITHDRAW_INTERVAL
      uint256(2 days)      //                                    PRESALE_WITHDRAW_INTERVAL
    ]
  )  public {
  }
}