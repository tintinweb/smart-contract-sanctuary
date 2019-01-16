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

  bool  public          startICO  = false;
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
  uint256 public Ico70PercentBalance  = 360000000 * (10 ** uint256(decimals)); // 360.000.000 BCEO
  uint256 public Ico100PercentBalance = 150000000 * (10 ** uint256(decimals)); // 150.000.000 BCEO

  uint256 public amountEtherLock = 0;
  uint256 public amountEtherNotLock = 0;
  uint256 public amountBCEONotLock = 0;

  uint256 public START_WITHDRAW;
  uint256 public END_WITHDRAW_ETHER;
  uint256 public TEAM_WITHDRAW_INTERVAL;
  uint256 public PRESALE_WITHDRAW_INTERVAL;

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

  constructor(
    uint256 _startWithdraw,
    uint256 _endWithdrawETH,
    uint256 _startTeamWithdraw,
    uint256 _startReverseWithdraw,
    uint256 _startPresaleWithdraw,
    uint256 _teamWithdrawInterval,
    uint256 _presaleWithdrawInterval
  ) public payable {
    START_WITHDRAW            = _startWithdraw;
    END_WITHDRAW_ETHER        = _endWithdrawETH;
    TEAM_WITHDRAW_INTERVAL    = _teamWithdrawInterval;
    PRESALE_WITHDRAW_INTERVAL = _presaleWithdrawInterval;

    teamWithdraw    = WithdrawInterval(0, _startTeamWithdraw, TeamBalance, false);
    reserveWithdraw = WithdrawInterval(0, _startReverseWithdraw, ReserveBalance, false);
    presaleWithdraw = WithdrawInterval(0, _startPresaleWithdraw, PreSaleBalance, false);
  }

  function startICO(address _addressBCEO) public onlyOwner returns (bool) {
    require(!startICO);
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
    startICO = true;
    return true;
  }

  function deposit70Percent() public payable isStartICO {
    // Number of tokens to sale in wei.
    uint256 amount = msg.value.mul(RATE_ICO_70);

    // Remain balance.
    require(Ico70PercentBalance >= amount);
    if (!address(this).send(msg.value)) {
      revert();
    }

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

  function deposit100Percent() public payable isStartICO {

    // Number of tokens to sale in wei.
    uint256 amount = msg.value.mul(RATE_ICO_100);

    // Remain balance.
    require(Ico100PercentBalance >= amount);
    
    if (!address(this).send(msg.value)) {
      revert();
    }

    // Minimum amount invest is 0.1 Ether.
    if (msg.value < MIN_AMOUNT_INVEST) {
      revert();
    }

    // Store balance of investor: ETH100 and BCEO.
    balanceOf[ETH100][msg.sender] = balanceOf[ETH100][msg.sender].add(amount);
    balanceOf[BCEO][msg.sender] = balanceOf[BCEO][msg.sender].add(amount);
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
    emit Convert("100_TO_70", _investorAddress, amountETH100,  balanceOf[ETH70][msg.sender]);

    // Unlock 30% amount Ether
    amountEtherLock = amountEtherLock.sub(threeTenth);
    amountEtherNotLock = amountEtherNotLock.add(threeTenth);

    // Transfer amount BCEO sold from Ico100 to Ico70
    Ico70PercentBalance = Ico70PercentBalance.sub(amountETH100.mul(RATE_ICO_70));
    Ico100PercentBalance = Ico100PercentBalance.add(amountETH100.mul(RATE_ICO_100));
  }

  function withdrawEther() public isStartICO returns (bool) {
    // Balances of investor.
    uint256 amountBCEO =  balanceOf[BCEO][msg.sender];
    uint256 amountETH70 =  balanceOf[ETH70][msg.sender];
    uint256 amountETH100 =  balanceOf[ETH100][msg.sender];
    uint256 amountEther = amountETH70.add(amountETH100); 

    // Validates balance and timestamp.
    require(block.timestamp >= START_WITHDRAW && block.timestamp <= END_WITHDRAW_ETHER);
    require(amountEther > 0);

    // Investor withdraws Ether so reduces the amount Ether and back BCEO to owner.
    amountEtherLock = amountEtherLock.sub(amountEther);
    amountBCEONotLock = amountBCEONotLock.add(amountBCEO);

    // Set balances&#39; Investor to 0 after withdrawing.
    balanceOf[BCEO][msg.sender] = 0;
    balanceOf[ETH70][msg.sender] = 0;
    balanceOf[ETH100][msg.sender] = 0;
    
    if (!msg.sender.send(amountEther)) revert();

    emit Withdraw("ETH", msg.sender, amountEther);
    return true;
  }

  function withdrawBCEO() public isStartICO returns (bool) {
    // Balances of invester.
    uint256 amountBCEO =  balanceOf[BCEO][msg.sender];
    uint256 amountETH70 =  balanceOf[ETH70][msg.sender];
    uint256 amountETH100 =  balanceOf[ETH100][msg.sender];
    uint256 amountEther = amountETH70.add(amountETH100); 

    // Validates balance and timestamp.
    require(block.timestamp >= START_WITHDRAW);
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

  function adminWithdrawEther() public onlyOwner isStartICO returns (bool) {
    // Unlock all Ether after END_WITHDRAW_ETHER 
    if (block.timestamp > END_WITHDRAW_ETHER) {
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

 

  function adminWithdrawBCEO(uint8 _withdrawType) public onlyOwner isStartICO returns (bool) {
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
      theWithdraw.nextTimestamp          = theWithdraw.nextTimestamp + PRESALE_WITHDRAW_INTERVAL;
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

  function adminWithdrawBCEOPreSale() public onlyOwner isStartICO returns (bool) {
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
      presaleWithdraw.nextTimestamp = presaleWithdraw.nextTimestamp + PRESALE_WITHDRAW_INTERVAL;
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
    return a > b ? a : b;
  }
  
  modifier isStartICO() {
    require(startICO);
    _;
  }
}
contract BitCEOIco is BitCEOIcoBase {

  constructor() BitCEOIcoBase(
    1556643600, //  May 1st, 2019 00:00:00 GMT+07:00
    1556902799, //  May 5th, 2019 23:59:59 GMT+07:00
    1556643600, //  May 1st, 2019 00:00:00 GMT+07:00
    1556643600, //  May 1st, 2019 00:00:00 GMT+07:00
    1556643600, //  May 1st, 2019 00:00:00 GMT+07:00
    30 days,
    2 days
  )  public payable {      
  }
}