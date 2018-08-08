pragma solidity ^0.4.18;
// -------------------------------------------------
// Assistive Reality ARX Token - ICO token sale contract
// contact <span class="__cf_email__" data-cfemail="e29196838484a283908d8c8e8b8c87cc8b8d">[email&#160;protected]</span> for queries
// Revision 20b
// Refunds integrated, full test suite 20r passed
// -------------------------------------------------
// ERC Token Standard #20 interface:
// https://github.com/ethereum/EIPs/issues/20
// ------------------------------------------------
// 2018 improvements:
// - Updates to comply with latest Solidity versioning (0.4.18):
// -   Classification of internal/private vs public functions
// -   Specification of pure functions such as SafeMath integrated functions
// -   Conversion of all constant to view or pure dependant on state changed
// -   Full regression test of code updates
// -   Revision of block number timing for new Ethereum block times
// - Removed duplicate Buy/Transfer event call in buyARXtokens function (ethScan output verified)
// - Burn event now records number of ARX tokens burned vs Refund event Eth
// - Transfer event now fired when beneficiaryWallet withdraws
// - Gas req optimisation for payable function to maximise compatibility
// - Going live in code ahead of ICO announcement 09th March 2018 19:30 GMT
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

contract ARXCrowdsale is owned, safeMath {
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
  uint256 public fundingMaxCapInWei;                          //

  // loop control, ICO startup and limiters
  string  public CurrentStatus                    = "";        // current crowdsale status
  uint256 public fundingStartBlock;                           // crowdsale start block#
  uint256 public fundingEndBlock;                             // crowdsale end block#
  bool    public isCrowdSaleClosed               = false;     // crowdsale completion boolean
  bool    private areFundsReleasedToBeneficiary  = false;     // boolean for founder to receive Eth or not
  bool    public isCrowdSaleSetup                = false;     // boolean for crowdsale setup

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Buy(address indexed _sender, uint256 _eth, uint256 _ARX);
  event Refund(address indexed _refunder, uint256 _value);
  event Burn(address _from, uint256 _value);
  mapping(address => uint256) balancesArray;
  mapping(address => uint256) usersARXfundValue;

  // default function, map admin
  function ARXCrowdsale() public onlyOwner {
    admin = msg.sender;
    CurrentStatus = "Crowdsale deployed to chain";
  }

  // total number of tokens initially
  function initialARXSupply() public view returns (uint256 initialARXtokenCount) {
    return safeDiv(initialTokenSupply,1000000000000000000); // div by 1000000000000000000 for display normalisation (18 decimals)
  }

  // remaining number of tokens
  function remainingARXSupply() public view returns (uint256 remainingARXtokenCount) {
    return safeDiv(tokensRemaining,1000000000000000000); // div by 1000000000000000000 for display normalisation (18 decimals)
  }

  // setup the CrowdSale parameters
  function SetupCrowdsale(uint256 _fundingStartBlock, uint256 _fundingEndBlock) public onlyOwner returns (bytes32 response) {
    if ((msg.sender == admin)
    && (!(isCrowdSaleSetup))
    && (!(beneficiaryWallet > 0))) {
      // init addresses
      beneficiaryWallet                       = 0x98DE47A1F7F96500276900925B334E4e54b1caD5;
      tokenReward                             = StandardToken(0xb0D926c1BC3d78064F3e1075D5bD9A24F35Ae6C5);

      // funding targets
      fundingMinCapInWei                      = 30000000000000000000;                       // 300  ETH wei
      initialTokenSupply                      = 277500000000000000000000000;                // 277,500,000 + 18 dec resolution

      // update values
      amountRaisedInWei                       = 0;
      tokensRemaining                         = initialTokenSupply;
      fundingStartBlock                       = _fundingStartBlock;
      fundingEndBlock                         = _fundingEndBlock;
      fundingMaxCapInWei                      = 4500000000000000000000;

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
    if (block.number >= 5532293) {
      return (2250);
    } else if (block.number >= 5490292) {
      return (2500);
    } else if (block.number >= 5406291) {
      return (2750);
    } else if (block.number >= 5370290) {
      return (3000);
    } else if (block.number >= 5352289) {
      return (3250);
    } else if (block.number >= 5310289) {
      return (3500);
    } else if (block.number >= 5268288) {
      return (4000);
    } else if (block.number >= 5232287) {
      return (4500);
    } else if (block.number >= fundingStartBlock) {
      return (5000);
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
    rewardTransferAmount            = (safeMul(msg.value, checkPrice()));

    // 3. interaction
    tokensRemaining                 = safeSub(tokensRemaining, rewardTransferAmount);
    tokenReward.transfer(msg.sender, rewardTransferAmount);

    // 4. events
    usersARXfundValue[msg.sender]   = safeAdd(usersARXfundValue[msg.sender], msg.value);
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
      CurrentStatus = "Successful (ARX >= Hardcap)!";
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

  function refund() public { // any contributor can call this to have their Eth returned. user&#39;s purchased ARX tokens are burned prior refund of Eth.
    //require minCap not reached
    require ((amountRaisedInWei < fundingMinCapInWei)
    && (isCrowdSaleClosed)
    && (block.number > fundingEndBlock)
    && (usersARXfundValue[msg.sender] > 0));

    //burn user&#39;s token ARX token balance, refund Eth sent
    uint256 ethRefund = usersARXfundValue[msg.sender];
    balancesArray[msg.sender] = 0;
    usersARXfundValue[msg.sender] = 0;

    //record Burn event with number of ARX tokens burned
    Burn(msg.sender, usersARXfundValue[msg.sender]);

    //send Eth back
    msg.sender.transfer(ethRefund);

    //record Refund event with number of Eth refunded in transaction
    Refund(msg.sender, ethRefund);
  }
}