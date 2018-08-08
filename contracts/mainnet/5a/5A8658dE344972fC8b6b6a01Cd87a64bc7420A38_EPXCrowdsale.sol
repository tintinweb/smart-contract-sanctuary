pragma solidity ^0.4.18;
// -------------------------------------------------
// ethPoker.io EPX token - Presale & ICO token sale contract
// Private Pre-sale preloaded sale contract
// 150ETH capped contract (only 1.5M tokens @ best 10,000 EPX:1ETH)
// 150ETH matches 1:1 ethPoker.io directors injection of 150ETH
// contact <span class="__cf_email__" data-cfemail="5f3e3b3236311f3a2b372f30343a2d713630">[email&#160;protected]</span> for queries
// Revision 20b
// Refunds integrated, full test suite 20r passed
// -------------------------------------------------
// ERC Token Standard #20 interface:
// https://github.com/ethereum/EIPs/issues/20
// EPX contract sources:
// https://github.com/EthPokerIO/ethpokerIO
// ------------------------------------------------
// 2018 improvements:
// - Updates to comply with latest Solidity versioning (0.4.18):
// -   Classification of internal/private vs public functions
// -   Specification of pure functions such as SafeMath integrated functions
// -   Conversion of all constant to view or pure dependant on state changed
// -   Full regression test of code updates
// -   Revision of block number timing for new Ethereum block times
// - Removed duplicate Buy/Transfer event call in buyEPXtokens function (ethScan output verified)
// - Burn event now records number of EPX tokens burned vs Refund event Eth
// - Transfer event now fired when beneficiaryWallet withdraws
// - Gas req optimisation for payable function to maximise compatibility
// - Going live for initial Presale round 02/03/2018
// -------------------------------------------------
// Security reviews passed - cycle 20r
// Functional reviews passed - cycle 20r
// Final code revision and regression test cycle passed - cycle 20r
// -------------------------------------------------

contract owned {
  address public owner;

  function owned() internal {
    owner = msg.sender;
  }
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
}

contract safeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    safeAssert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    safeAssert(b > 0);
    uint256 c = a / b;
    safeAssert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    safeAssert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    safeAssert(c>=a && c>=b);
    return c;
  }

  function safeAssert(bool assertion) internal pure {
    if (!assertion) revert();
  }
}

contract StandardToken is owned, safeMath {
  function balanceOf(address who) view public returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract EPXCrowdsale is owned, safeMath {
  // owner/admin & token reward
  address        public admin                     = owner;    // admin address
  StandardToken  public tokenReward;                          // address of the token used as reward

  // deployment variables for static supply sale
  uint256 private initialTokenSupply;
  uint256 private tokensRemaining;

  // multi-sig addresses and price variable
  address private beneficiaryWallet;                           // beneficiaryMultiSig (founder group) or wallet account

  // uint256 values for min,max,caps,tracking
  uint256 public amountRaisedInWei;                           //
  uint256 public fundingMinCapInWei;                          //

  // loop control, ICO startup and limiters
  string  public CurrentStatus                    = "";        // current crowdsale status
  uint256 public fundingStartBlock;                           // crowdsale start block#
  uint256 public fundingEndBlock;                             // crowdsale end block#
  bool    public isCrowdSaleClosed               = false;     // crowdsale completion boolean
  bool    private areFundsReleasedToBeneficiary  = false;     // boolean for founder to receive Eth or not
  bool    public isCrowdSaleSetup                = false;     // boolean for crowdsale setup

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Buy(address indexed _sender, uint256 _eth, uint256 _EPX);
  event Refund(address indexed _refunder, uint256 _value);
  event Burn(address _from, uint256 _value);
  mapping(address => uint256) balancesArray;
  mapping(address => uint256) usersEPXfundValue;

  // default function, map admin
  function EPXCrowdsale() public onlyOwner {
    admin = msg.sender;
    CurrentStatus = "Crowdsale deployed to chain";
  }

  // total number of tokens initially
  function initialEPXSupply() public view returns (uint256 initialEPXtokenCount) {
    return safeDiv(initialTokenSupply,10000); // div by 10,000 for display normalisation (4 decimals)
  }

  // remaining number of tokens
  function remainingEPXSupply() public view returns (uint256 remainingEPXtokenCount) {
    return safeDiv(tokensRemaining,10000); // div by 10,000 for display normalisation (4 decimals)
  }

  // setup the CrowdSale parameters
  function SetupCrowdsale(uint256 _fundingStartBlock, uint256 _fundingEndBlock) public onlyOwner returns (bytes32 response) {
    if ((msg.sender == admin)
    && (!(isCrowdSaleSetup))
    && (!(beneficiaryWallet > 0))) {
      // init addresses
      beneficiaryWallet                       = 0x7A29e1343c6a107ce78199F1b3a1d2952efd77bA;
      tokenReward                             = StandardToken(0x35BAA72038F127f9f8C8f9B491049f64f377914d);

      // funding targets
      fundingMinCapInWei                      = 10000000000000000000;

      // update values
      amountRaisedInWei                       = 0;
      initialTokenSupply                      = 15000000000;
      tokensRemaining                         = initialTokenSupply;
      fundingStartBlock                       = _fundingStartBlock;
      fundingEndBlock                         = _fundingEndBlock;

      // configure crowdsale
      isCrowdSaleSetup                        = true;
      isCrowdSaleClosed                       = false;
      CurrentStatus                           = "Crowdsale is setup";
      return "Crowdsale is setup";
    } else if (msg.sender != admin) {
      return "not authorised";
    } else  {
      return "campaign cannot be changed";
    }
  }

  function checkPrice() internal view returns (uint256 currentPriceValue) {
    if (block.number >= fundingStartBlock+177534) { // 30-day price change/final 30day change
      return (8500); //30days-end   =8,500EPX:1ETH
    } else if (block.number >= fundingStartBlock+124274) { //3 week mark/over 21days
      return (9250); //3w-30days    =9,250EPX:1ETH
    } else if (block.number >= fundingStartBlock) { // start [0 hrs]
      return (10000); //0-3weeks     =10,000EPX:1ETH
    }
  }

  // default payable function when sending ether to this contract
  function () public payable {
    // 0. conditions (length, crowdsale setup, zero check, exceed funding contrib check, contract valid check, within funding block range check, balance overflow check etc)
    require(!(msg.value == 0)
    && (msg.data.length == 0)
    && (block.number <= fundingEndBlock)
    && (block.number >= fundingStartBlock)
    && (tokensRemaining > 0));

    // 1. vars
    uint256 rewardTransferAmount    = 0;

    // 2. effects
    amountRaisedInWei               = safeAdd(amountRaisedInWei, msg.value);
    rewardTransferAmount            = ((safeMul(msg.value, checkPrice())) / 100000000000000);

    // 3. interaction
    tokensRemaining                 = safeSub(tokensRemaining, rewardTransferAmount);
    tokenReward.transfer(msg.sender, rewardTransferAmount);

    // 4. events
    usersEPXfundValue[msg.sender]   = safeAdd(usersEPXfundValue[msg.sender], msg.value);
    Buy(msg.sender, msg.value, rewardTransferAmount);
  }

  function beneficiaryMultiSigWithdraw(uint256 _amount) public onlyOwner {
    require(areFundsReleasedToBeneficiary && (amountRaisedInWei >= fundingMinCapInWei));
    beneficiaryWallet.transfer(_amount);
    Transfer(this, beneficiaryWallet, _amount);
  }

  function checkGoalReached() public onlyOwner { // return crowdfund status to owner for each result case, update public vars
    // update state & status variables
    require (isCrowdSaleSetup);
    if ((amountRaisedInWei < fundingMinCapInWei) && (block.number <= fundingEndBlock && block.number >= fundingStartBlock)) { // ICO in progress, under softcap
      areFundsReleasedToBeneficiary = false;
      isCrowdSaleClosed = false;
      CurrentStatus = "In progress (Eth < Softcap)";
    } else if ((amountRaisedInWei < fundingMinCapInWei) && (block.number < fundingStartBlock)) { // ICO has not started
      areFundsReleasedToBeneficiary = false;
      isCrowdSaleClosed = false;
      CurrentStatus = "Crowdsale is setup";
    } else if ((amountRaisedInWei < fundingMinCapInWei) && (block.number > fundingEndBlock)) { // ICO ended, under softcap
      areFundsReleasedToBeneficiary = false;
      isCrowdSaleClosed = true;
      CurrentStatus = "Unsuccessful (Eth < Softcap)";
    } else if ((amountRaisedInWei >= fundingMinCapInWei) && (tokensRemaining == 0)) { // ICO ended, all tokens bought!
      areFundsReleasedToBeneficiary = true;
      isCrowdSaleClosed = true;
      CurrentStatus = "Successful (EPX >= Hardcap)!";
    } else if ((amountRaisedInWei >= fundingMinCapInWei) && (block.number > fundingEndBlock) && (tokensRemaining > 0)) { // ICO ended, over softcap!
      areFundsReleasedToBeneficiary = true;
      isCrowdSaleClosed = true;
      CurrentStatus = "Successful (Eth >= Softcap)!";
    } else if ((amountRaisedInWei >= fundingMinCapInWei) && (tokensRemaining > 0) && (block.number <= fundingEndBlock)) { // ICO in progress, over softcap!
      areFundsReleasedToBeneficiary = true;
      isCrowdSaleClosed = false;
      CurrentStatus = "In progress (Eth >= Softcap)!";
    }
  }

  function refund() public { // any contributor can call this to have their Eth returned. user&#39;s purchased EPX tokens are burned prior refund of Eth.
    //require minCap not reached
    require ((amountRaisedInWei < fundingMinCapInWei)
    && (isCrowdSaleClosed)
    && (block.number > fundingEndBlock)
    && (usersEPXfundValue[msg.sender] > 0));

    //burn user&#39;s token EPX token balance, refund Eth sent
    uint256 ethRefund = usersEPXfundValue[msg.sender];
    balancesArray[msg.sender] = 0;
    usersEPXfundValue[msg.sender] = 0;

    //record Burn event with number of EPX tokens burned
    Burn(msg.sender, usersEPXfundValue[msg.sender]);

    //send Eth back
    msg.sender.transfer(ethRefund);

    //record Refund event with number of Eth refunded in transaction
    Refund(msg.sender, ethRefund);
  }
}